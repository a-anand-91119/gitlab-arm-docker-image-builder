# Self-Hosted Gitlab CE arm docker image builder
This repository will build docker images for GitLab CE that can be used in arm devices inlcuding systems with Ampere processors.

## How to use these images?
Whether you use the docker image directly or via `docker compose` is upto you. Attaching a sample docker-compose.yml file for reference on how to setup your own GitLab CE instance via docker in arm processors.

```yml
version: '3.6'
services:
  gitlab:
    image: 'registry.gitlab.com/a_anand_91119/gitlab-arm:$GITLAB_IMAGE_TAG'
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

> Create a `.env` along with this docker compose and set the value for `GITLAB_HOME` and `GITLAB_IMAGE_TAG`.

```env
GITLAB_HOME=/home/ubuntu/gitlab
GITLAB_IMAGE_TAG=Any_Tag_Available_In_This_Repository
```

## How to get a particular version of GitLab whose image is not availabe?
If you need a version of gitlab that is not already available, just raise an issue with the exact version you need.

## Upgrading self-hosted GitLab instances
To upgrade your self-hosted instance
1. First go to [Gitlab Upgrade Path](https://gitlab-com.gitlab.io/support/toolbox/upgrade-path/?distro=docker&edition=ce)
2. Fill in the details such as
    - The current version of your GitLab Instance
    - The version to which you are planning to upgrade to
    - The edition [`Community Edition`]
    - The distro. [`Docker`]
3. Once filled in the website will show the upgrade path to your target version from your current version.
![GitLab Upgade Path from 16.8.1 to 17.3.1](docs/upgrade_path_16.8.1_to_17.3.1.png)
    - In this example the upgrade path from `16.8.1` to `17.3.1` is being shown.
    - First we need to upgarde from `16.8.1` to `16.11.8`, start the instance finish all the migrations 
    - And then upgrade from `16.11.8` to `17.3.1`.
