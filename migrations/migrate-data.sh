#!/bin/bash
set -e

GITLAB_HOME="/home/ubuntu/gitlab"

echo "Stopping GitLab container..."
docker compose down

echo "Migrating Git repositories..."
sudo cp -a $GITLAB_HOME/data/git-data/repositories $GITLAB_HOME/data-ce/git-data/

echo "Migrating uploads..."
sudo cp -a $GITLAB_HOME/data/gitlab-rails/uploads $GITLAB_HOME/data-ce/gitlab-rails/

echo "Migrating shared data (artifacts, LFS, pages, packages)..."
sudo cp -a $GITLAB_HOME/data/gitlab-rails/shared $GITLAB_HOME/data-ce/gitlab-rails/

echo "Migrating SSH keys..."
sudo cp -a $GITLAB_HOME/data/.ssh $GITLAB_HOME/data-ce/

echo "Migrating Git config..."
sudo cp $GITLAB_HOME/data/.gitconfig $GITLAB_HOME/data-ce/

echo "Migrating container registry..."
sudo cp -a $GITLAB_HOME/data/registry $GITLAB_HOME/data-ce/

echo "Fixing permissions..."
sudo chown -R 998:998 $GITLAB_HOME/data-ce

echo "Starting GitLab..."
docker compose up -d

echo "Migration complete! Monitor logs with: docker logs -f gitlab"
