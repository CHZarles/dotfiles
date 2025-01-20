# dotfiles

# bild Docker image

```
cp nvim ./dockerize_nvim -r
cd ./dockerize_nvim
python build.py
```

config

```.bashrc

start_nvim_container() {
    dest_path=$(pwd)
    HOME=$HOME
    if [ "$(sudo docker ps -aq -f name=nvim-ide)" ]; then
        echo "Container dnvim already exists."
    else
        # otherwise run the image and name it dnvim
        sudo docker run -d -it --rm -v ${HOME}/workspace:${HOME}/workspace -v ${HOME}/.config/github-copilot:${HOME}/.config/github-copilot --name nvim-ide nvim-ide:latest
    fi

            # 判断 dest_path 是否在 ${HOME}/workspace 中
        if [[ "${dest_path}" = "${HOME}/workspace"* ]] ; then
            docker exec -it nvim-ide sh -c "cd '${dest_path}' ; nvim ."
        else
            echo "Error: dest_path is not in ${HOME}/workspace."
        fi
}

alias dnvim='start_nvim_container'

```
