var React = require('react');
 
function DefaultLayout(props) {
  return (
    <html>
      <head>
          <meta charSet="utf-8"/>
          <meta name="viewport" content="width=device-width, initial-scale=1"/>
          <title>{props.title}</title>
          {/* <link rel="stylesheet" href="css/bulma.min.css"/> */}
          <link rel="stylesheet" href="css/styles.css"/>
      </head> 
      <body>{props.children}</body>
    </html>
  );
}
 
module.exports = DefaultLayout;