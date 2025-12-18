FROM fluent/fluentd-kubernetes-daemonset:v1.17.1-debian-elasticsearch8-1.2
RUN gem install fluent-plugin-haproxy && \
    gem install fluent-plugin-rewrite-tag-filter
USER root
