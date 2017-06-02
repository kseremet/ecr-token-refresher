FROM rhel7.3

MAINTAINER Koray Seremet <koray@redhat.com>

LABEL name="ecr-token-refresher" \
      architecture="x86_64" \
      io.k8s.display-name="ECR Token Refresher" \
      io.k8s.description="Amazon ECR registry token refresher" \
      io.openshift.tags="openshift,aws,ecr"

RUN ["pip", "install", "--upgrade", "pip", "awscli", "boto3"]
COPY scripts/ecr-token-refresher.sh /usr/local/bin
CMD /usr/local/bin/ecr-token-refresher.sh
