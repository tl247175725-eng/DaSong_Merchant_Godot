@echo off
echo ==========================================
echo       大宋货郎项目 - 自动化发货中...
echo ==========================================
git add .
git commit -m "CEO One-Click Sync"
git push origin master
echo ==========================================
echo       ✅ 发货成功！代码已覆盖 GitHub 仓库。
echo ==========================================
pause