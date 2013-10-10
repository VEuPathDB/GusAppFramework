package edu.upenn.cbil.magetab.model;

import org.apache.commons.lang.StringUtils;

public enum ImageExtension {
  
  GIF, PNG;
  
  static public boolean has(String value) {
    if (StringUtils.isEmpty(value)) return false;
	try {
	  valueOf(value.toUpperCase());
	  return true;
	}
	catch (IllegalArgumentException x) { 
	  return false;
	}
  }
}