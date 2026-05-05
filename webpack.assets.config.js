const path = require('path');
const glob = require('glob');
const defaultConfig = require('@wordpress/scripts/config/webpack.config');
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
const RtlCssPlugin = require('@wordpress/scripts/plugins/rtlcss-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

/**
 * ------------------------------------------------------------
 * Build entry points from resources/assets/src/**
 * ------------------------------------------------------------
 */
const entries = {};

glob.sync('./resources/assets/src/*/index.js').forEach((file) => {
  const name = path.basename(path.dirname(file));
  entries[name] = path.resolve(__dirname, file);
});

glob.sync('./resources/assets/src/*/*/index.js').forEach((file) => {
  const dir = path.dirname(file);
  const parent = path.basename(path.dirname(dir));
  const name = `${parent}/${path.basename(dir)}`;
  entries[name] = path.resolve(__dirname, file);
});

console.log('Webpack Entries:', entries);

/**
 * ------------------------------------------------------------
 * Export config
 * ------------------------------------------------------------
 */
module.exports = {
  ...defaultConfig,

  /**
   * Scope webpack to assets only
   */
  context: path.resolve(__dirname, 'resources/assets'),
  entry: entries,

  /**
   * Output into assets build directory
   */
  output: {
    ...defaultConfig.output,
    path: path.resolve(__dirname, 'resources/assets/build'),
    filename: '[name]/index.js',
    clean: true,
  },

  /**
   * Disable block chunk splitting
   */
  optimization: {
    ...defaultConfig.optimization,
    splitChunks: {
      cacheGroups: {
        ...defaultConfig.optimization.splitChunks.cacheGroups,
        style: false,
      },
    },
  },

  /**
   * Remove block-specific plugins and add CSS extraction
   */
  plugins: [
    ...defaultConfig.plugins.filter(
      (plugin) =>
        !(plugin instanceof MiniCssExtractPlugin) &&
        !(plugin instanceof RtlCssPlugin) &&
        !(plugin instanceof CopyWebpackPlugin)
    ),

    new MiniCssExtractPlugin({
      filename: ({ chunk }) => `${chunk.name}/style-index.css`,
    }),

    new CopyWebpackPlugin({
      patterns: [
        {
          from: '**/dependencies.php',
          context: path.resolve(__dirname, 'resources/assets/src'),
          to: path.resolve(__dirname, 'resources/assets/build'),
          noErrorOnMissing: true,
        },
        {
          from: '**/config.php',
          context: path.resolve(__dirname, 'resources/assets/src'),
          to: path.resolve(__dirname, 'resources/assets/build'),
          noErrorOnMissing: true,
        }
      ],
    }),
  ]
};