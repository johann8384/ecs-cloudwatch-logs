FROM oraclelinux:7
MAINTAINER Jonathan Creasy <jcreasy@rgare.com>

ENV WORKDIR /opt/awslogs
ENV LOGSTORAGE /var/log/syslog

ENV AWS_REGION us-west-2

RUN mkdir -p $LOGSTORAGE
RUN mkdir -p $WORKDIR

WORKDIR $WORKDIR

RUN /usr/bin/curl http://mirror.us.leaseweb.net/epel/7/x86_64/e/epel-release-7-5.noarch.rpm -o $WORKDIR/epel-release-7-5.noarch.rpm
RUN /usr/bin/yum -y install $WORKDIR/epel-release-7-5.noarch.rpm
RUN /usr/bin/yum clean all
RUN /usr/bin/yum -y update
RUN /usr/bin/yum -y install python python-pip
RUN /usr/bin/yum -y install rsyslog crontabs which
RUN /usr/bin/yum install -y supervisor

COPY rsyslog_remote_logs.conf /etc/rsyslog.d/rsyslog_remote_logs.conf
COPY awslogs.conf $WORKDIR/awslogs.conf
COPY supervisord.conf /etc/supervisord.d/supervisord-awslogs.ini

RUN chmod 0444 /etc/rsyslog.d/rsyslog_remote_logs.conf
RUN chmod 0444 $WORKDIR/awslogs.conf
RUN chmod 0444 /etc/supervisord.d/supervisord-awslogs.ini

RUN sed -i "s/#\$ModLoad imudp/\$ModLoad imudp/" /etc/rsyslog.conf && \
  sed -i "s/#\$UDPServerRun 514/\$UDPServerRun 514/" /etc/rsyslog.conf && \
  sed -i "s/#\$ModLoad imtcp/\$ModLoad imtcp/" /etc/rsyslog.conf && \
  sed -i "s/#\$InputTCPServerRun 514/\$InputTCPServerRun 514/" /etc/rsyslog.conf
RUN sed -i "s/nodaemon=false/nodaemon=true/" /etc/supervisord.conf

RUN /usr/bin/curl https://s3.amazonaws.com/aws-cloudwatch/downloads/latest/awslogs-agent-setup.py -o $WORKDIR/awslogs-agent-setup.py
RUN /usr/bin/python $WORKDIR/awslogs-agent-setup.py -n -r $AWS_REGION -c $WORKDIR/awslogs.conf

EXPOSE 514/tcp 514/udp 8080/tcp
CMD ["/usr/bin/supervisord"]
