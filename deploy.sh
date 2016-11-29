# hexo generate -d 命令失效，将hexo分支推送到了master分支。使用此脚本进行部署
# 将此脚步置于与blog同级目录下。
# 部署
folder="./blogdeploy"
blog="./Hikyu.github.io"
if [ ! -d "$folder" ]; then
  mkdir "$folder"
  cd "$folder"
  git clone git@github.com:Hikyu/Hikyu.github.io.git
  cd ..
fi
cd "$blog"
hexo generate
cp -R ./public/* ../"$folder"
cd ../"$folder"
git add .
git commit -m 'update'
git push origin master
# 备份博客源码到hexo分支
cd ../"$blog"
git add .
git commit -m 'update'
git push origin hexo
