'use strict';

exports.handler = async event => {
  // TODO implement
  const response = {
    statusCode: 200,
    body: JSON.stringify('Hello from Lambda! v1.1.1'),
  };
  return response;
};
