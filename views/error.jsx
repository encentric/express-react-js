var React = require('react');
var DefaultLayout = require('./layouts/default');
 
function ErrorView(props) {
  return (
    <DefaultLayout title={this.props.error.status}>
        <div>Error {this.props.message}</div>
    </DefaultLayout>
  );
}
 
module.exports = ErrorView;