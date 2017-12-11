# hexo generate -d 命令失效，将hexo分支推送到了master分支。使用此脚本进行部署
# 将此脚步置于与blog同级目录下。
# 部署
root="/home/yukai/project/blog"
folder="$root/blogdeploy"
blog="$root/Hikyu.github.io"
if [ ! -d "$folder" ]; then
  echo "初始化..."
  mkdir "$folder"
  cp -R "$blog/.git/" "$folder/.git/"
  cd "$folder"
  git checkout master
fi
echo "博客生成..."
cd "$blog"
git checkout hexo
hexo generate
cp -R "$blog"/public/* "$folder"
echo "博客发布..."
cd "$folder"
git add --all .
git commit -m 'update'
git push --force origin master
echo "备份博客源码到hexo分支..."
cd "$blog"
git add --all .
git commit -m 'update'
git push --force origin hexo
