package edu.upenn.cbil.biomatgraph;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;

public class ProtocolApplication {
  private long protocolApplicationId;
  private int step;
  private String name;
  private String description;
  private String performer;
  private List<String> parameters;
  private String dbId;
  
  public ProtocolApplication() {
    this.description = "";
    this.parameters = new ArrayList<>();
  }
  
  public ProtocolApplication(long protocolApplicationId) {
    this();
    this.step = 1;
    this.protocolApplicationId = protocolApplicationId;
  }
  
  public final long getProtocolApplicationId() {
    return protocolApplicationId;
  }

  public final void setProtocolApplicationId(long protocolApplicationId) {
    this.protocolApplicationId = protocolApplicationId;
  }

  public final int getStep() {
    return step;
  }

  public final void setStep(int step) {
    this.step = step;
  }
  
  public final String getName() {
    return name;
  }

  public final void setName(String name) {
    this.name = name;
  }

  public final String getDescription() {
    return description;
  }

  public final void setDescription(String description) {
    this.description = description;
  }

  public final List<String> getParameters() {
    return parameters;
  }

  public final String getPerformer() {
    return performer;
  }

  public final void setPerformer(String performer) {
    this.performer = performer;
  }

  /**
   * Convenient string representation for debugging purposes.
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field field) {
        return super.accept(field);
      }
    }).toString();
  }
  
}
