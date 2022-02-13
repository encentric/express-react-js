# Express React JS

A template repo for a server side rendered node.js web app using express and react for views

Additional aspects:
  - Bulma for css+sass but easily replaceable 
  - Babel for nextgen js in the browser, typescript for type checking only (no emit/compile) 
  - Webpack for bundling client side js and css
  - Dev inner loop including watch for changes and unit tests (TODO)
  - E2E tests (TODO)
  - Containers and K8s deploys (TODO)

# Node.js

The repo is using node 16 which is currently latest LTS.  

# Local Dev

Watches for file changes and restarts

once:
```bash
$ npm install
```

```bash
$ npm start
```

# Production Container

builds the container image

```bash
$ ./dev image

# or, npm run image
```

```bash
$ docker images | grep express-react-js
express-react-js    0.1.0-main0009 91f7cc965c9f   39 seconds ago   130MB
```

note that if you want to build locally (debug etc) what's happening in the container build you can run:

```bash
$ ./dev build

# or, npm run build
```

 # Resources

[express](https://expressjs.com/)  
[bulma and webpack](https://bulma.io/documentation/customize/with-webpack/)   
[typescript for checking only (no emit)](https://www.sitepen.com/blog/progressively-adopting-typescript-in-an-application)  

