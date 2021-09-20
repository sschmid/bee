FROM bash:5.0.18
RUN apk add --no-cache git

WORKDIR /usr/local/opt/bee
COPY src/ src/
COPY etc/ etc/
COPY CHANGELOG.md LICENSE.txt version.txt ./

RUN echo "source /usr/local/opt/bee/etc/bash_completion.d/bee-completion.bash" > /root/.bashrc
RUN ln -s /usr/local/opt/bee/src/bee /usr/local/bin/bee

WORKDIR /project
CMD ["bash"]
