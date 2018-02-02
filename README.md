# Incunabula

## Build instructions

```
git clone https://github.com/gordonguthrie/incunabula.git
cd incunabula/
mix deps.get
npm install semantic-ui -save
mkdir web/static/vendor
cp -R semantic/dist/* web/static/vendor/
```

Manually frig `semantic/dist/semantic.css` and change all the `./themes/default/assets/fonts` etc to `../vendor/themes/default/assets/fonts`

These will be in:

* `icon.min.css`
* `icon.css`
* `semantic.min.css`
* `semantic.css`

Then you are all ready
```
./start_incunabula.sh
```
