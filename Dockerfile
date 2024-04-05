FROM amazon/aws-lambda-ruby:3.2

RUN yum groupinstall -y "Development Tools"
RUN yum install -y \
      ImageMagick \
      ImageMagick-devel \
      awscli \
      python3-dev \
      python3-pip

RUN pip3 uninstall urllib3 && \
      pip3 install "urllib3<1.27,>=1.25.4"

RUN pip3 install aws-sam-cli

COPY layers/process_documents /opt

WORKDIR /var/task
