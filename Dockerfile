FROM scratch

COPY marathonctl /

ENTRYPOINT ["/marathonctl"]
CMD ["--help"]
