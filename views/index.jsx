var React = require('react');
var DefaultLayout = require('./layouts/default');
 
function IndexView(props) {
  return (
    <DefaultLayout title={props.title}>
        <section class="section">
            <div class="container">
            <h1 class="title">
                Hello {props.name}
            </h1>
            <p class="subtitle" id="subtitle">
                Subtitle here
            </p>
            </div>
        </section> 
        <script src="bundle.js"></script>
    </DefaultLayout>
  );
}
 
module.exports = IndexView;