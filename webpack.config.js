const path = require('path');
const MiniCssExtractPlugin = require('mini-css-extract-plugin')
// const htmlWebpack = require('html-webpack-plugin');

module.exports = {
  entry: ['./javascript/app.js', './stylesheets/style.scss'],
  output: {
    path: path.resolve(__dirname, 'public'),
    filename: "[name].js",
    sourceMapFilename: "[name].js.map"    
  },
  plugins: [
    new MiniCssExtractPlugin({
        filename: "[name].css"
    })
  ],  
  devtool: "source-map",
  module: {
    rules: [
      {
        test: /\.s?css$/,
        use: [
          MiniCssExtractPlugin.loader,
          'css-loader',
          'sass-loader'
        ]
      },
      {
        test: /\.(woff(2)?|ttf|eot|svg)(\?v=\d+\.\d+\.\d+)?$/,
        use: [
          {
            loader: 'file-loader',
            options: {
              name: '[name].[ext]',
              outputPath: 'fonts/'
            }
          }
        ]
      }
    ]
  }
}

  