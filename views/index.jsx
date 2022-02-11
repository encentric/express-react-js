var React = require('react');
var DefaultLayout = require('./layouts/default');
 
function IndexView(props) {
  return (
    <DefaultLayout title={props.title}>
        <section className="section">
            <div className="container">
            <h1 className="title">
                Hello {props.name}
            </h1>
            <p className="subtitle" id="subtitle">
                Subtitle here
            </p>
            </div>
        </section> 
        <script src="bundle.js"></script>
    </DefaultLayout>
  );
}
 
module.exports = IndexView;