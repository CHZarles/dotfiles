import os
import subprocess


def get_username():
    return subprocess.check_output(["id", "-un"]).decode().strip()


def replace_username_in_template(template_path, output_path, username):
    with open(template_path, "r") as template_file:
        content = template_file.read()

    content = content.replace("{USERNAME}", username)

    with open(output_path, "w") as output_file:
        output_file.write(content)


def get_user_info():
    user_group = subprocess.check_output(["id", "-gn"]).decode().strip()
    user_gid = subprocess.check_output(["id", "-g"]).decode().strip()
    user = subprocess.check_output(["id", "-un"]).decode().strip()
    user_uid = subprocess.check_output(["id", "-u"]).decode().strip()
    with open("addusr.sh", "w") as file:
        file.write(f"#!/bin/sh\n")
        file.write(f"echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel\n")
        file.write(f"addgroup -g {user_gid} {user_group}\n")
        file.write(f"adduser -u {user_uid} -G {user_group} -D -s /bin/sh {user}\n")
        file.write(f"echo '{user}:123456' | chpasswd\n")
        # config passwd 123456
        file.write(f"adduser {user} wheel")


def main():
    # generate user info file
    get_user_info()

    # generate Dockerfile
    username = get_username()
    template_path = "Dockerfile_template"
    output_path = "Dockerfile"
    replace_username_in_template(template_path, output_path, username)
    print(f"Dockerfile has been generated with username: {username}")

    # run docker build
    os.system("sudo docker build -t nvim-ide:latest .")


if __name__ == "__main__":
    main()
