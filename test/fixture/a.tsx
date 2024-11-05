/* eslint-disable import/no-unresolved */

import React from          'react';

          export interface HelloWorldProps {
    name:     string
}


/* eslint-disable react/prefer-stateless-function */
export default class HelloWorld extends    React.Component <HelloWorldProps> {
  render() {
    const { name
    
    } = this.props;
    return (
      <div>{name}</div>
    );
  }
}
