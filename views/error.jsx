var React = require('react');
var DefaultLayout = require('./layouts/default');
 
function ErrorView(props) {
  return (
    <DefaultLayout title={props.error.status}>
        <div>Error {props.message}</div>
    </DefaultLayout>
  );
}
 
module.exports = ErrorView;