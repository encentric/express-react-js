var React = require('react');
var DefaultLayout = require('./layouts/default');
 
function IndexView(props) {
  return (
    <DefaultLayout title={props.title}>
        <div className="py-20" style={{background: 'linear-gradient(90deg, #667eea 0%, #764ba2 100%)'}}>
          <div className="container mx-auto px-6">
            <h1 className="text-3xl font-bold underline">
              Hello {props.name}
            </h1>
            <p className="subtitle" id="subtitle">
                Subtitle here
            </p>
          </div>
        </div> 
        <script src="bundle.js"></script>
    </DefaultLayout>
  );
}
 
module.exports = IndexView;