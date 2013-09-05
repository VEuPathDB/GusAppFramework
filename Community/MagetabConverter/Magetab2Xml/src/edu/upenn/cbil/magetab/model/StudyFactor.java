package edu.upenn.cbil.magetab.model;

import java.lang.reflect.Field;
import java.util.HashSet;
import java.util.Set;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

public class StudyFactor {
  private String name;
  private boolean addition;
  private static Set<String> names = new HashSet<>();
  private static Set<String> addedNames = new HashSet<>();
  
  public StudyFactor(String name, boolean addition) {
    this.name = name;
    names.add(name);
    this.addition = addition;
    if(addition) {
      addedNames.add(name);
    }
  }
  
  public String getName() {
	return name;
  }
  
  public boolean isAddition() {
	return addition;
  }
  
  public static Set<String> getNames() {
    return names;
  }
  
  public static Set<String> getAddedNames() {
    return addedNames;
  }
  
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }
}
