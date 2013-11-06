package edu.upenn.cbil.limpopo.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang.StringUtils;
import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.SDRF;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.graph.Node;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.ProtocolApplicationNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SDRFNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.ParameterValueAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.ProtocolObjectComparator;

public class ProtocolApplication extends ProtocolObject {
  private String name;
  private boolean addition;
  private String dbId;
  private Set<ProtocolApplicationIONode> inputs;
  private Set<ProtocolApplicationIONode> outputs;
  private List<Performer> performers;
  private List<ProtocolApplicationParameter> parameters;
  private String date;
  private ProtocolApplication subordinate;
  private ProtocolApplication superior;
  private static List<ProtocolApplication> applications = new ArrayList<>();
  private List<ProtocolApplication> subordinateApps;
  private static Set<ProtocolSeries> series = new HashSet<>();
  public static Logger logger = LoggerFactory.getLogger(ProtocolApplication.class);
  public static final String COMMENT = "Comment";

  public ProtocolApplication(SDRFNode node) throws ConversionException {
    super(node);
    addition = false;
    dbId = "";
    date = "";
    performers = new ArrayList<>();
	inputs = new LinkedHashSet<>();
	outputs = new LinkedHashSet<>();
	populate();
	logger.trace(this.toString());
  }
  
  public String getName() {
	return name;
  }
  
  /**
   * Sets name of protocol application (edge) but also removes any addition tokens.
   * @param name - raw name
   */
  public void setName(String name) {
    this.name = AppUtils.removeTokens(name);
  }

  public final boolean isAddition() {
    return addition;
  }
  public final void setAddition(boolean addition) {
    this.addition = addition;
  }
  public final String getDbId() {
    return dbId;
  }

  public final void setDbId(String dbId) {
    this.dbId = dbId;
  }
  
  public List<Performer> getPerformers() {
    return performers;
  }
  public String getDate() {
    return date;
  }
  
  public final List<ProtocolApplicationParameter> getParameters() {
    return parameters;
  }

  public final void setParameters(List<ProtocolApplicationParameter> parameters) {
    this.parameters = parameters;
  }

  /**
   * Set date of protocol application (edge) but also reomves any addition tokens.
   * @param date - raw date
   */
  public void setDate(String date) {
    this.date = AppUtils.removeTokens(date);
  }
  public Set<ProtocolApplicationIONode> getInputs() {
    return inputs;
  }
  public Set<ProtocolApplicationIONode> getOutputs() {
    return outputs;
  }
  public ProtocolApplication getSubordinate() {
    return subordinate;
  }
  public void setSubordinate(ProtocolApplication subordinate) {
    this.subordinate = subordinate;
  }
  public final List<ProtocolApplication> getSubordinateApps() {
    return subordinateApps;
  }
  public final void setSubordinateApps(List<ProtocolApplication> subordinateApps) {
    this.subordinateApps = subordinateApps;
  }
  public ProtocolApplication getSuperior() {
    return superior;
  }
  public void setSuperior(ProtocolApplication superior) {
    this.superior = superior;
  }
  public static List<ProtocolApplication> getApplications() {
	return applications;
  }
  public static final Set<ProtocolSeries> getSeries() {
    return series;
  }

  /**
   * Identifies whether this protocol app is subordinate to another in a protocol series.
   * @return - true is the protocol is not subordinate to any other protocol.
   */
  public boolean isTopmost() {
	return superior == null;
  }
  /**
   * Identifies whether or not this protocol app is part of a protocol series
   * @return - true is the protocol app does not belong to a protocol series.
   */
  public boolean isStandalone() {
	return superior == null && subordinate == null;
  }
  public String getLabel() {
    return WordUtils.wrap(name, 30, "\\n", true);
  }
  
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      protected boolean accept(Field f) {
        //return super.accept(f) && !f.getName().equals("node");
        return super.accept(f);
      }
    }).toString();
  }
  
  @Override
  public boolean equals(Object obj) {
    if (obj instanceof ProtocolApplication) {
      ProtocolApplication that = (ProtocolApplication) obj;
      boolean nodesEqual = that.getNode().equals(getNode());
      return nodesEqual;
    }
    else {
      return false;
    }
  }
  
  /**
   * Populate the protocol application reference (edge or part of edge).  Determine if the protocol reference
   * is an addition.  Remove tokens from any subordinate components of the protocol application
   * ref.
   * @throws ConversionException - thrown if a performer cannot be satisfactorily parsed.
   */
  public void populate() throws ConversionException {
    ProtocolApplicationNode appNode = (ProtocolApplicationNode) node;
    String name = appNode.protocol;
    if(StringUtils.isEmpty(name)) {
      ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      ErrorItem error = factory.generateErrorItem("Check your SDRF", 8001, this.getClass());
      throw new ConversionException(true, error);
    }
	setName(name);
	setAddition(AppUtils.checkForAddition(name));
	setDbId(AppUtils.filterIdToken(name));
	assembleParameters();
	if(appNode.performer != null) {
	  performers.add(new Performer(appNode.performer, addition));
	}
	setDate(appNode.date);
  }
  
  /**
   * Assembles parameters for this protocol application (edge or part of edge).  Parameter type, value, table (optional)
   * and row (optional) are separated by pipes (The optional PV table and PV row must appear together or not at
   * all and must be associated with a parameter).  Distinct parameters are separated by semi-colons.
   * @throws ConversionException - Code 7001
   * SOP 16. If Comment [PV Row Id] has a value Comment [PV Table]) must have a value and conversely.
   */
  public void assembleParameters() throws ConversionException {
    parameters = new ArrayList<>();
    List<ParameterValueAttribute> params = ((ProtocolApplicationNode)node).parameterValues;
    for(ParameterValueAttribute param : params) {
      ProtocolApplicationParameter parameter = new ProtocolApplicationParameter(name, param, addition);
      parameters.add(parameter);
    }
  }
  
  public static void setContext() throws ConversionException {
    for(ProtocolApplication application : ProtocolApplication.getApplications()) {
      if(application.hasSuperior()) {
        Node superiorNode = application.getNode().getParentNodes().toArray(new Node[0])[0];
        ProtocolApplication superior = findByNode(superiorNode);
        application.setSuperior(superior);
      }
      if(application.hasSubordinate()) {
        Node subordinateNode = application.getNode().getChildNodes().toArray(new Node[0])[0];
        ProtocolApplication subordinate = findByNode(subordinateNode);
        application.setSubordinate(subordinate);
      }
    }
    for(ProtocolApplication application : ProtocolApplication.getApplications()) {
      application.setInputNodes();
      application.setOutputNodes();
      if(application.isTopmost() && !application.isStandalone()) {
        //System.out.println("Topmost ID in Series: " + application.id + " name " + application.name);
    	application.createSubordinateApplicationList();
        application.createSeries();
        application.constructSeriesData();
      }
    }
  }
  

  public static ProtocolApplication findByNode(Node node) {
    ProtocolApplication found = null;
    for(ProtocolApplication application : ProtocolApplication.getApplications()) {
      if(node.equals(application.getNode())) {
        found = application;
      }
    }
    return found;
  }
  
  public boolean hasSubordinate() {
    boolean flag = false;
    Set<Node> children = node.getChildNodes();
    if(children.size() == 1) {
      Node child = children.toArray(new Node[0])[0];
      if("protocolref".equals(child.getNodeType())) {
        flag = true;
      }
    }
    return flag;
  }
  
  public boolean hasSuperior() {
    boolean flag = false;
    Set<Node> parents = node.getParentNodes();
    if(parents.size() == 1) {
      Node parent = parents.toArray(new Node[0])[0];
      if("protocolref".equals(parent.getNodeType())) {
        flag = true;
      }
    }
    return flag;
  }
  
  public  Set<ProtocolApplicationIONode> setOutputNodes() throws ConversionException {
    if(subordinate == null) {
      Set<Node> children = node.getChildNodes();
      for(Node child : children) {
        ProtocolApplicationIONode output = ProtocolApplicationIONode.findByNode(child);
        if(output == null) {
          output = new ProtocolApplicationIONode((SDRFNode)child);
        }
        outputs.add(output);
      }
    }
    else {
      outputs = subordinate.setOutputNodes();
    }
    return outputs;
  }
  
  public Set<ProtocolApplicationIONode> setInputNodes() throws ConversionException {
    if(superior == null) {
      Set<Node> parents = node.getParentNodes();
      for(Node parent : parents) {
    	ProtocolApplicationIONode input = ProtocolApplicationIONode.findByNode(parent);
    	if(input == null) {
    	  input = new ProtocolApplicationIONode((SDRFNode)parent);
    	}
        inputs.add(input);
      }
    }
    else {
      inputs = superior.setInputNodes();
    }
    return inputs;
  }
  
  /**
   * Called only when the calling protocol application is the topmost application
   * of a protocol application series.  Creates an ordered list of subordinate
   * protocol applications to be used to create a protocol series and to
   * consolidate a protocol application series into one protocol application
   */
  public void createSubordinateApplicationList() {
    subordinateApps = new ArrayList<>();
    ProtocolApplication app = this;
    while(app.subordinate != null) {
      app = app.subordinate;
      subordinateApps.add(app);
    }
  }
  
  /**
   * Called only when the calling protocol application is the topmost application
   * of a protocol application series. Prepends the current, topmost, protocol application
   * and uses that list to create a protocol series to be added into the IDF.
   */
  public void createSeries() {
    List<ProtocolApplication> seriesApps = new ArrayList<>();
    seriesApps.add(this);
    seriesApps.addAll(subordinateApps);
    series.add(new ProtocolSeries(seriesApps));
  }
  
  /**
   * Called only when the calling protocol application is the topmost application
   * of a protocol application series.  Appends the name for subordinate protocol
   * applications to this, the topmost protocol application.
   */
  public void constructSeriesData() {
    for(ProtocolApplication subordinateApp : subordinateApps) {
      name += ";" + subordinateApp.name;
    }
  }
  
  /**
   * Assembles a set of performer names drawn from the SDRF for validation.  Addition/id
   * tokens are filtered out.
   * @param data - SDRF data
   * @return - a set of filtered SDRF performer names
   */
  public static Set<String> getPerformerNames(SDRF data) {
    Set<String> performerNames = new HashSet<>();
    Collection<? extends ProtocolApplicationNode> nodes = data.getNodes(ProtocolApplicationNode.class);
    for(ProtocolApplicationNode node : nodes) {
      if(node.performer != null && StringUtils.isNotEmpty(node.performer.getNodeName())) {
        // Strip add/id tokens if present
        performerNames.add(AppUtils.removeTokens(node.performer.getNodeName()));
      }
    }
    return performerNames;
  }
  
  
  /**
   * Assembles a list of protocol application references (edges) for a given protocol name in the SDRF
   * to be used for validation.  Addition/id tokens are filtered out.
   * @param data - SDRF data
   * @return - filtered mapping of each SDRF protocol name to a list of protocol application nodes.
   */
  public static Map<String, List<ProtocolApplicationNode>> createProtocolNodeMap(SDRF data) {
    Map<String, List<ProtocolApplicationNode>> map = new HashMap<>();
    Collection<? extends ProtocolApplicationNode> nodes = data.getNodes(ProtocolApplicationNode.class);
    for(ProtocolApplicationNode node : nodes) {
      List<ProtocolApplicationNode> nodeList = new ArrayList<>();
      // Strip add/id tokens if present
      String protocolName = AppUtils.removeTokens(node.protocol);
      if(map.containsKey(protocolName)) {
        nodeList = map.get(protocolName);
      }
      nodeList.add(node);
      map.put(protocolName, nodeList);
    }
    return map;
  }

  public static void createAllProtocolApplications(SDRF data) throws ConversionException {
	Collection<? extends SDRFNode> nodes = data.getNodes(ProtocolApplicationNode.class);
	for(Node node : nodes) {
	  ProtocolApplication application = new ProtocolApplication((SDRFNode)node);
	  applications.add(application);
	}
	Collections.sort(applications, new ProtocolObjectComparator());
	ProtocolApplication.setContext();
  }
}
