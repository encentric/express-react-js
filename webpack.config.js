const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin')

// webpack watch can also run the node server and restart via nodemon
const NodemonPlugin = require('nodemon-webpack-plugin');

module.exports = {
    entry: './public/index.js',
    output: {
        path: path.resolve(__dirname, 'public', 'dist'),
        filename: 'bundle.js'
    },
    module: {
        rules: [
            {
                test: /\.m?js$/,
                exclude: /node_modules/,
                use: {
                    loader: "babel-loader",
                    options: {
                        presets: ['@babel/preset-env']
                    }
                }
            },
            {
                test: /\.scss$/,
                use: [
                    MiniCssExtractPlugin.loader,
                    {
                        loader: 'css-loader'
                    },
                    {
                        loader: 'sass-loader',
                        options: {
                            sourceMap: true,
                            // options...
                        }
                    }
                ]
            }]
    },
    plugins: [
        new MiniCssExtractPlugin({
            filename: 'css/styles.css'
        }),
        new NodemonPlugin({
            script: './bin/www',
            // types complains about this but it's not readonly.  
            // necessary to restart on server and client changes
            watch: ".",
            ext: 'js,jsx,json',
            env: {
                NODE_ENV: 'development',
            },            
        }),
    ]
};