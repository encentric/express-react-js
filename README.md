# Express React JS

[![ci](https://github.com/encentric/express-react-js/actions/workflows/ci.yaml/badge.svg)](https://github.com/encentric/express-react-js/actions/workflows/ci.yaml)

A template repo for a server side rendered `node.js` web app using `express` and `react` for views

Additional aspects:
  - `tailwinds` for css+sass but easily replaceable 
  - `Babel` for nextgen js in the browser, `typescript` for type checking only (no emit/compile) 
  - `Webpack` for bundling client side js and css
  - Dev inner loop including watch for changes
  - E2E tests   
  - `GitHub actions` for CI, CD (deploy) with approvals
  - `Containers`, `docker` multi-stage build and `K8s` deploys
 
# Node.js

The repo is using node 16 which is currently latest LTS.  

# Local Dev

Starts the server and restarts on file changes  

once:
```bash
$ npm install
```

```bash
$ npm start
```

# Container

builds the container image

```bash
$ ./dev image
```

Run and stop container
```bash
$ ./dev run
...

$ ./dev stop
```

note that if you want to build locally (debug etc) what's happening in the container build you can run:

```bash
$ ./dev build
```

# Test

Spin up the container and test outside / in.  

```bash
$ ./dev e2e
```

# Deploy

`./dev deploy {targetEnv} [-y]`  

`targetEnv`: dev, staging, prod  
`-y`: avoids prompt to continue  

```bash
$ ./dev deploy dev -y

Deploying to dev
----------------------
...
```



 # Resources

[express](https://expressjs.com/)   
[babel+typescript](https://iamturns.com/typescript-babel/)     
[typescript for checking only (no emit)](https://www.sitepen.com/blog/progressively-adopting-typescript-in-an-application)  

[tailwinds css + webpack](https://tailwindcss.com/docs/installation/using-postcss)
[tailwinds css + webpack](https://dev.to/ynwd/how-to-integrate-tailwind-react-and-webpack-2gdf)  
[tailwind css + webpack](https://gsc13.medium.com/how-to-configure-webpack-5-to-work-with-tailwindcss-and-postcss-905f335aac2)  
https://stackoverflow.com/questions/55606865/combining-tailwind-css-with-sass-using-webpack
[tailwind hero+parallax](https://daily-dev-tips.com/posts/tailwind-css-parallax-effect/)  
[postcss](https://github.com/postcss/postcss#webpack) and [this](https://stackoverflow.com/a/55607208/775184)  

