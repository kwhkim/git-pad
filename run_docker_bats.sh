docker run -d --name bats-dev \
              --user root \
              --entrypoint /bin/sh \
              -v "$PWD:/code" \
              -v "/home/gogpu/.ssh:/root/.ssh" \
              -v bats-git-issue:/code/git-issue \
              bats/bats \
              -c "while true; do sleep 3600; done"