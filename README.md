# Self-Hosted Gitlab CE arm docker image builder
This repository will build docker images for GitLab CE that can be used in arm devices inlcuding systems with Ampere processors.

## How to use these images?
Whether you use the docker image directly or via `docker compose` is upto you. Attaching a sample docker-compose.yml file for reference on how to setup your own GitLab CE instance via docker in arm processors.

```yml
version: '3.6'
services:
  gitlab:
    image: 'registry.gitlab.com/a_anand_91119/gitlab-arm:GITLAB_IMAGE_TAG'
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

## How to use gitlab version for which images are not available?
