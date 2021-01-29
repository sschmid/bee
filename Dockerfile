FROM bash
COPY . /usr/local/opt/bee/
COPY .bashrc /root/
RUN ln -s /usr/local/opt/bee/src/bee /usr/local/bin/bee
RUN apk add --no-cache util-linux perl-utils git
WORKDIR /project
CMD ["bash"]
