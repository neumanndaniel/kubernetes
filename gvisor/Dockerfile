FROM alpine:3.15.0
COPY install-gvisor.sh /
COPY run.sh /
RUN chmod u+x run.sh
CMD ["./run.sh"]