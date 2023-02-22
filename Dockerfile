FROM lambci/lambda:build-ruby2.7

# Lock down AWS SAM version.
RUN pip install awscli && \
    pip uninstall --yes aws-sam-cli && \
    pip install Jinja2==2.11.3 && \
    pip install aws-sam-cli

RUN yum install -y ImageMagick ImageMagick-devel

COPY layers/process_documents /opt

WORKDIR /var/task
