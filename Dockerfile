FROM bash:5.0.18
WORKDIR /usr/local/opt/bee
COPY src/ src/
COPY etc/ etc/
COPY CHANGELOG.md LICENSE.txt version.txt ./
COPY .bashrc /root/
RUN ln -s /usr/local/opt/bee/src/bee /usr/local/bin/bee
RUN apk add --no-cache util-linux git
WORKDIR /project
CMD ["bash"]
