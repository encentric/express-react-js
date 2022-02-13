# Express React JS

A template repo for a server side rendered node.js web app using express and react for views

Additional aspects:
  - Bulma for css+sass but easily replaceable 
  - Babel for nextgen js in the browser, typescript for type checking only (no emit/compile) 
  - Webpack for bundling client side js and css
  - Dev inner loop including watch for changes
  - Containers, docker multi-stage build and K8s deploys
  - E2E tests  

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

Run and stop container
```bash
$ ./dev run

...

$ ./dev stop
```

note that if you want to build locally (debug etc) what's happening in the container build you can run:

```bash
$ ./dev build

# or, npm run build
```

# e2e test container

```bash
$ ./dev e2e

e2e...
----------------------

stopping
----------------------

run
----------------------
d0f6fb416a63feb483fe46d76ebc377c31f8b78f098114dc7c81386949d0fe15

tests
----------------------
test home page
            <h1 class="title">Hello World</h1>

stopping
----------------------
```

 # Resources

[express](https://expressjs.com/)  
[bulma and webpack](https://bulma.io/documentation/customize/with-webpack/)   
[typescript for checking only (no emit)](https://www.sitepen.com/blog/progressively-adopting-typescript-in-an-application)  

