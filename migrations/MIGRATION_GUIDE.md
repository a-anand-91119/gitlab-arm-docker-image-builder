# GitLab ARM Migration Guide

## Migrating from aanand91119/gitlab-arm to Official GitLab Images

This guide helps you migrate from custom ARM images (`aanand91119/gitlab-arm`) to official GitLab ARM64 images when
there's a PostgreSQL architecture mismatch.

## Background

Due to PostgreSQL compilation differences between `aanand91119/gitlab-arm` images and official GitLab images, you cannot
directly upgrade using standard backup/restore methods. The custom ARM images use 32-bit PostgreSQL flags (
`USE_FLOAT8_BYVAL` disabled), while official images use proper 64-bit compilation.

**Version Gap:**

- Latest `aanand91119/gitlab-arm` image: **17.11.7-ce.0**
- Earliest official GitLab ARM64 image: **18.2.0-ce.0**

This version gap prevents using `gitlab-ctl backup` and `restore` processes. Instead, you must use **logical database
dumps**.

---

## Migration Steps

### Prerequisites

Your original `docker-compose.yml`:

```yaml
version: '3.6'
services:
  gitlab:
    image: 'aanand91119/gitlab-arm:$GITLAB_IMAGE_TAG'
    restart: always
    container_name: gitlab
    hostname: 'gitlab.yourdomain.com'
    ports:
      - '80:80'
      - '443:443'
      - '8443:22'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data:/var/opt/gitlab'
    shm_size: '256m'
```

---

### Step 1: Create Database Dump from Old Instance

1. **Start your old container** (if not already running):
   ```bash
   docker-compose up -d
   ```

2. **Enter the container**:
   ```bash
   docker exec -it gitlab sh
   ```

3. **Create the logical database dump**:
   ```bash
   /opt/gitlab/embedded/bin/chpst -u gitlab-psql:gitlab-psql -U gitlab-psql /usr/bin/env PGSSLCOMPRESSION=0 /opt/gitlab/embedded/bin/pg_dump -p 5432 -h /var/opt/gitlab/postgresql -d gitlabhq_production > /var/opt/gitlab/backups/gitlab-dump.sql
   ```

4. **Exit the container**:
   ```bash
   exit
   ```

5. **Verify the dump** was created in `$GITLAB_HOME/data/backups/gitlab-dump.sql`:
   ```bash
   ls -lh $GITLAB_HOME/data/backups/gitlab-dump.sql
   ```

6. **Stop the old container**:
   ```bash
   docker-compose down
   ```

---

### Step 2: Update Docker Compose Configuration

Update your `docker-compose.yml` with the following changes:

```yaml
services:
  gitlab:
    image: gitlab/gitlab-ce:18.2.0-ce.0
    restart: always
    container_name: gitlab
    hostname: 'gitlab.yourdomain.com'
    ports:
      - '80:80'
      - '443:443'
      - '8443:22'
    volumes:
      - '$GITLAB_HOME/config:/etc/gitlab'
      - '$GITLAB_HOME/logs:/var/log/gitlab'
      - '$GITLAB_HOME/data-ce:/var/opt/gitlab'
      - '$GITLAB_HOME/data/backups:/var/opt/gitlab/backups'
    shm_size: '256m'
```

**Important changes:**

- ✅ Use official image: `gitlab/gitlab-ce:18.2.0-ce.0`
- ✅ New data directory: `$GITLAB_HOME/data-ce:/var/opt/gitlab`
- ✅ Mount old backups: `$GITLAB_HOME/data/backups:/var/opt/gitlab/backups`

---

### Step 3: Initialize New GitLab Instance

1. **Start the new container**:
   ```bash
   docker-compose up -d
   ```

2. **Wait for initialization** (5-10 minutes):
   ```bash
   docker logs -f gitlab
   ```

   Look for the message: `gitlab Reconfigured!`

3. **Verify the instance is accessible**:
    - Open your GitLab URL in a browser
    - The page should load (your old credentials won't work yet)

---

### Step 4: Restore Database Dump

1. **Enter the new container**:
   ```bash
   docker exec -it gitlab sh
   ```

2. **Stop application services**:
   ```bash
   gitlab-ctl stop puma
   gitlab-ctl stop sidekiq
   ```

3. **Drop and recreate the database schema**:
   ```bash
   gitlab-psql
   ```

   In the PostgreSQL shell:
   ```sql
   DROP SCHEMA public CASCADE;
   CREATE SCHEMA public;
   \q
   ```

4. **Restore the database dump**:
   ```bash
   /opt/gitlab/embedded/bin/chpst -u gitlab-psql:gitlab-psql -U gitlab-psql /usr/bin/env PGSSLCOMPRESSION=0 /opt/gitlab/embedded/bin/psql -p 5432 -h /var/opt/gitlab/postgresql -d gitlabhq_production < /var/opt/gitlab/backups/gitlab-dump.sql
   ```

5. **Wait for restoration to complete** (this may take several minutes depending on database size)

6. **Run database migrations**:
   ```bash
   gitlab-rake db:migrate
   ```

7. **Restart all services**:
   ```bash
   gitlab-ctl restart
   ```

8. **Verify the migration**:
   ```bash
   gitlab-rake gitlab:check
   ```

9. **Exit the container**:
   ```bash
   exit
   ```

---

### Step 5: Copy critical data
Update the `GITLAB_HOME` variable in [migrate-data.sh](migrate-data.sh) file and run the script.
> Please be sure to verify that the userId used in script 998 corresponds to the `polkitd` user and group. (use `ls -ln` to get the id)


### Step 6: Verify and Cleanup

1. **Test your GitLab instance**:
    - Log in using your old credentials
    - Verify projects, users, and settings are intact
    - Test pushing/pulling code

2. **Once confirmed working, clean up old data**:
   ```bash
   # Optional: Keep a backup for safety
   sudo mv $GITLAB_HOME/data $GITLAB_HOME/data-old-backup

   # Or delete if confident:
   # sudo rm -rf $GITLAB_HOME/data
   ```

3. **Update your docker-compose.yml** to use the new data directory permanently:
   ```yaml
   volumes:
     - '$GITLAB_HOME/config:/etc/gitlab'
     - '$GITLAB_HOME/logs:/var/log/gitlab'
     - '$GITLAB_HOME/data-ce:/var/opt/gitlab'
   ```
---

## Troubleshooting

### Issue: Database dump fails with authentication error

**Solution**: Ensure you're using the correct `chpst` command with proper user switching:

```bash
/opt/gitlab/embedded/bin/chpst -u gitlab-psql:gitlab-psql -U gitlab-psql /usr/bin/env PGSSLCOMPRESSION=0 /opt/gitlab/embedded/bin/pg_dump ...
```

> To get this command, run `which gitlab-psql` to see the location of the gitlab-psql binary. Then edit it to echo the
> command it uses along with all the variables filled. After which run it once more and you'll see the proper command.

### Issue: Restore fails with permission errors

**Solution**: Make sure you stopped `puma` and `sidekiq` before restoring:

```bash
gitlab-ctl stop puma
gitlab-ctl stop sidekiq
```

### Issue: Services won't start after restore

**Solution**: Check logs and reconfigure:

```bash
gitlab-ctl tail
gitlab-ctl reconfigure
gitlab-ctl restart
```

### Issue: Migration takes too long

**Solution**: This is normal for large databases. Monitor progress:

```bash
docker exec gitlab gitlab-ctl tail postgresql
```

---

## Additional Notes

- **Backup Strategy**: Always keep your old `data` directory until you've fully verified the migration
- **Downtime**: Plan for 30-60 minutes of downtime depending on database size

---

## References

- PostgreSQL
  `USE_FLOAT8_BYVAL` [architecture compatibility](https://www.postgresql.org/docs/current/runtime-config-compatible.html)
