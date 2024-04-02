FROM amazon/aws-lambda-ruby:3.2

RUN yum install -y ImageMagick ImageMagick-devel

COPY layers/process_documents /opt

WORKDIR /var/task
