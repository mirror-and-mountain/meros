const path = require('path');
const glob = require('glob');
const defaultConfig = require('@wordpress/scripts/config/webpack.config');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RtlCssPlugin = require('@wordpress/scripts/plugins/rtlcss-webpack-plugin');

// Dynamically create entries from `assets/src/*/index.js`
const entries = {};
glob.sync('./assets/src/*/index.js').forEach((file) => {
  const name = path.basename(path.dirname(file));
  entries[name] = path.resolve(__dirname, file);
});

module.exports = {
  ...defaultConfig,

  entry: entries,

  output: {
    ...defaultConfig.output,
    path: path.resolve(__dirname, 'assets/build'),
    filename: '[name]/index.js',
    clean: true,
  },

  optimization: {
    ...defaultConfig.optimization,
    splitChunks: {
      cacheGroups: {
        ...defaultConfig.optimization.splitChunks.cacheGroups,
        style: false,
      },
    },
  },

  plugins: [
    ...defaultConfig.plugins.filter(
      (plugin) =>
        !(plugin instanceof MiniCssExtractPlugin) && !(plugin instanceof RtlCssPlugin) 
    ),

    new MiniCssExtractPlugin({
      filename: ({ chunk }) => `${chunk.name}/style-index.css`,
    }),
  ],
};