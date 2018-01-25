# Incunabula

## Build instructions

```
git clone https://github.com/gordonguthrie/incunabula.git
cd incunabula/
mix deps.get
npm install semantic-ui -save
mkdir web/static/vendor
cp -R semantic/dist/* web/static/vendor/
./start_incunabula.sh
```
