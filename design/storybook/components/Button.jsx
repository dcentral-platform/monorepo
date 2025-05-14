import React from 'react';
import PropTypes from 'prop-types';
import '../../global.css';

/**
 * Primary UI component for user interaction
 */
export const Button = ({
  primary,
  size,
  backgroundColor,
  label,
  ...props
}) => {
  const mode = primary ? 'bg-primary hover:bg-primary-700 text-white' : 'bg-secondary hover:bg-secondary-700 text-white';
  
  const sizeClass = {
    small: 'py-1.5 px-4 text-sm',
    medium: 'py-2.5 px-5 text-base',
    large: 'py-3 px-6 text-lg',
  }[size];
  
  return (
    <button
      type="button"
      className={[
        'font-medium rounded-lg shadow-sm transition-colors',
        mode,
        sizeClass,
      ].join(' ')}
      style={backgroundColor ? { backgroundColor } : {}}
      {...props}
    >
      {label}
    </button>
  );
};

Button.propTypes = {
  /**
   * Is this the principal call to action on the page?
   */
  primary: PropTypes.bool,
  /**
   * How large should the button be?
   */
  size: PropTypes.oneOf(['small', 'medium', 'large']),
  /**
   * Button contents
   */
  label: PropTypes.string.isRequired,
  /**
   * Optional custom background color
   */
  backgroundColor: PropTypes.string,
  /**
   * Optional click handler
   */
  onClick: PropTypes.func,
};

Button.defaultProps = {
  primary: true,
  size: 'medium',
  backgroundColor: null,
  onClick: undefined,
};