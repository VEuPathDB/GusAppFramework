package edu.upenn.cbil.limpopo.model;

import java.util.ArrayList;
import java.util.List;

import com.google.common.base.Joiner;

/**
 * A series of protocols applied in sequence not interrupted by a material entity or data
 * source.  Elucidated from the SDRF and applied a posteriori to the IDF portion of the xml
 * output.
 * @author crisl
 *
 */
public class ProtocolSeries {
  private boolean addition;
  private boolean applicationAddition;
  private String name;
  private List<ProtocolApplication> protocolApplications;
  private static List<ProtocolSeries> protocolSeriesList = new ArrayList<>();
  
  /**
   * Constructor the accepts an ordered list of the component protocol applications to
   * harvest the protocol names and whether any component protocol is an addition.
   * @param protocolApplications - list of component protocol applications.
   */
  public ProtocolSeries(List<ProtocolApplication> protocolApplications) {
    this.protocolApplications = protocolApplications;
    setAddition();
    setApplicationAddition();
    setName();
    ProtocolSeries.protocolSeriesList.add(this);
  }
  
  /**
   * Returns whether or not this series is an addition.  A series is an addition if
   * any combination of protocol components is an addition.  However, a series may also
   * be an addition even if the component protocols are not.  In that case the series is
   * a new arrangement of original protocols.  This cannot be known until all the
   * protocol applications have been processed.  So interpret this result advisedly.
   * @return - true if addition, false otherwise.
   */
  public boolean isAddition() {
    return this.addition;
  }
  
  /**
   * Helper method to establish whether any of the component protocols is an
   * addition and set the series addition flag accordingly.  This setting does not
   * account for the possibility of a new arrangement of original protocols.
   */
  protected void setAddition() {
    addition = false;
    for(ProtocolApplication protocolApplication : protocolApplications) {
      Protocol protocol = Protocol.getProtocolByName(protocolApplication.getName());
      if(protocol != null && protocol.isAddition()) {
        addition = true;
        break;
      }
    }
  }
  
  /**
   * Helper method to correct the series addition flag in the event that the series consists
   * of original protocols combined in new ways.
   * @param addition - 
   */
  protected void setAdditionTrue() {
    this.addition = true;
  }
  
  protected boolean isApplicationAddition() {
    return this.applicationAddition;
  }
  
  /**
   * Helper method to identify whether any of the component protocol applications
   * are additions.  Needed to help identify a series that contains original protocols
   * but in fact constitutes an added series.
   */
  protected void setApplicationAddition() {
    applicationAddition = false;
    for(ProtocolApplication protocolApplication : protocolApplications) {
      if(protocolApplication.isAddition()) {
        applicationAddition = true;
        break;
      }
    }
  }
  
  /**
   * The addition flag created when a new series is constructed only accounts for series that
   * contain protocols that have been added.  The possibility exists of a series which is composed
   * of original protocols in a new arrangement.  This too is an addition but cannot be determined
   * prior to the identification of all protocol series in the SDRF.  So this method is called
   * after the SDRF data is fully parsed.  If the series has not previously been determined to
   * be an addition but if one or more of the protocol applications that gave rise to it is an
   * addition, see whether there is another instantiation of the series but without any added
   * component protocol applications.  If not, the series represents a new arrangement of original
   * protocols and so constitutes an addition.
   * @param series - the series to examined for possible adjustment of the addition flag.
   */
  public static void adjustAddition(ProtocolSeries series) {
    if(!series.isAddition() && series.isApplicationAddition()) {
      boolean prior = false;
      for(ProtocolSeries protocolSeries : protocolSeriesList) {
        if(protocolSeries.equals(series) && !protocolSeries.isApplicationAddition()) {
          prior = true;
          break;
        }
      }
      if(prior == false) {
        series.setAdditionTrue();
      }
    }
  }
  
  public String getName() {
    return this.name;
  }
  
  protected void setName() {
    List<String> names = new ArrayList<>();
    for(ProtocolApplication protocolApplication : protocolApplications) {
      names.add(protocolApplication.getName());
    }
    Joiner joiner = Joiner.on(";").skipNulls();
    this.name = joiner.join(names);
  }
  
  /**
   * Removes hash code from consideration of object equality.
   */
  @Override public int hashCode() {
    return 0;
  }
  
  /**
   * Compares protocol series based solely on the series name and addition field.
   */
  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ProtocolSeries) {
      ProtocolSeries that = (ProtocolSeries) obj;
      boolean namesEqual = that.getName().equals(getName());
      return namesEqual;
    }
    else {
      return false;
    }
  }
  
}
