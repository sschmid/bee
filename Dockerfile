FROM bash
COPY src/ /usr/local/opt/bee/src/
COPY etc/ /usr/local/opt/bee/etc/
COPY version.txt /usr/local/opt/bee/
COPY .bashrc /root/
RUN ln -s /usr/local/opt/bee/src/bee /usr/local/bin/bee
RUN apk add --no-cache util-linux git
WORKDIR /project
CMD ["bash"]
