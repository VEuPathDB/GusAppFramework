package edu.upenn.cbil.limpopo.utils;

import java.util.List;

public class ListUtils {

	public static String get(List<String> list, int i) {
      String value = "";
      if(list.size() > i) value = list.get(i);
      return value;
	}
	
}
