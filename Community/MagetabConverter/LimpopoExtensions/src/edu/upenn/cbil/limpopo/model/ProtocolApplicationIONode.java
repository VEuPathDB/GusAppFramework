package edu.upenn.cbil.limpopo.model;

import java.lang.reflect.Field;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang.WordUtils;
import org.apache.commons.lang.builder.ReflectionToStringBuilder;
import org.apache.commons.lang.builder.ToStringStyle;
import org.mged.magetab.error.ErrorItem;
import org.mged.magetab.error.ErrorItemFactory;

import uk.ac.ebi.arrayexpress2.magetab.datamodel.graph.Node;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.ExtractNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.LabeledExtractNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SDRFNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SampleNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.SourceNode;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.CharacteristicsAttribute;
import uk.ac.ebi.arrayexpress2.magetab.datamodel.sdrf.node.attribute.MaterialTypeAttribute;
import uk.ac.ebi.arrayexpress2.magetab.exception.ConversionException;
import edu.upenn.cbil.limpopo.utils.AppUtils;
import edu.upenn.cbil.limpopo.utils.SDRFUtils;

/**
 * This object represents the node in a biomaterials graph and is derived from Limpopo's SDRF node.
 * @author crisl
 *
 */
public class ProtocolApplicationIONode extends ProtocolObject {

  private boolean addition;
  private String dbId;
  private String name;
  private String type;
  private String description;
  private List<Characteristic> characteristics;
  private String taxon;
  private String uri;
  private String sourceId;
  private String extDbRls;
  private String table;
  private static Set<ProtocolApplicationIONode> applicationIONodes = new LinkedHashSet<>();
  public static final String ORGANISM = "organism";
  public static final String SCAN_NAME = "scanname";
  public static final String ASSAY_NAME = "assayname";
  public static final String CHARACTERISTICS = "Characteristics";
  public static final String COMMENT = "Comment";
  public static final String FACTOR_VALUE = "Factor Value";
  public static final String MATERIAL_ENTITY = "material entity";
  public static final String DATA_ITEM = "data item";
  public static final String PROTOCOL_REF = "protocolref";
  public static final String URI = "uri";
  public static final String[] NODES_WITH_CHARACTERISTICS = {"samplename", "sourcename", "extractname", "labeledextractname"};
  public static final String[] POSSIBLE_MATERIAL_ENTITIES = {"samplename", "sourcename", "extractname", "labeledextractname", "normalizationname", "assayname" }; 
  
  /**
   * Creates a protocol application IO node from an appropriate SDRFNode.
   * @param node - appropriate SDRF node
   * @throws ConversionException - caused by ontology term or node type problems most likely.
   */
  public ProtocolApplicationIONode(SDRFNode node) throws ConversionException {
    super(node);
    addition = false;
    dbId = "";
    populate();
    ProtocolApplicationIONode.applicationIONodes.add(this);
  }
  
  public final String getDbId() {
    return dbId;
  }

  public final boolean isAddition() {
    return addition;
  }

  /**
   * Set of SDRF protocol application IO nodes (nodes) obtained from parsing the SDRF
   * @return - set of SDRF protocol application IO nodes
   */
  public static Set<ProtocolApplicationIONode> getApplicationIONodes() {
	return applicationIONodes;
  }
  
  /**
   * The underlying SDRF node for this protocol application IO node
   * @return - SDRF node
   */
  @Override
  public SDRFNode getNode() {
	return node;
  }
  public void setNode(SDRFNode node) {
	this.node = node;
  }
  public String getName() {
	return name;
  }
  public void setName(String name) {
	this.name = AppUtils.removeTokens(name);
  }
  public String getType() {
	return type;
  }
  public void setType(String type) {
	this.type = AppUtils.removeTokens(type);
  }
  public String getDescription() {
	return description;
  }
  public void setDescription(String description) {
    this.description = AppUtils.removeTokens(description);
  }
  public String getTaxon() {
    return taxon;
  }
  public void setTaxon(String taxon) {
    this.taxon = AppUtils.removeTokens(taxon);
  }
  public String getUri() {
    return uri;
  }
  public void setUri(String uri) {
    this.uri = AppUtils.removeTokens(uri);
  }
  public String getSourceId() {
    return sourceId;
  }
  public void setSourceId(String sourceId) {
    this.sourceId = AppUtils.removeTokens(sourceId);
  }
  public String getExtDbRls() {
    return extDbRls;
  }
  public void setExtDbRls(String extDbRls) {
    this.extDbRls = extDbRls;
  }
  public List<Characteristic> getCharacteristics() {
    return characteristics;
  }
  public void setCharacteristics(List<Characteristic> characteristics) {
    this.characteristics = characteristics;
  }

  /**
   * Comment [Table] header.  Applied as a node characteristic and applicable only for 'file' nodes.
   * @return - table - an optional Schema :: Table string (may return an empty string).
   */
  public String getTable() {
    return table;
  }
  public final void setTable(String table) {
    this.table = AppUtils.removeTokens(table);
  }
  
  public String getLabel() {
    return WordUtils.wrap(name, 15, "\\n", true);
  }
  
  public String getColor() {
    String color = "black";
    switch(type) {
      case DATA_ITEM:
        color = "red";
        break;
      case MATERIAL_ENTITY:
        color = "blue";
        break;
      default:
    }
    return color;
  }

  /**
   * @return - a complete representation of the protocol application IO node using
   *           ReflectionToStringBuilder for debugging purposes.  The untranslated
   *           SDRF fields are not shown.
   */
  @Override
  public String toString() {
    return (new ReflectionToStringBuilder(this, ToStringStyle.MULTI_LINE_STYLE) {
      @Override
      protected boolean accept(Field f) {
        return super.accept(f) && !f.getName().equals("node");
      }
    }).toString();
  }
  
  /**
   * Populate the fields of an SDRF node.  Note that factor values are NOT accomodated here
   * because the current MAGE-TAB spec does not permit Comments trailing factor values.  So
   * limpopo does not accommodate such.  Since CBIL uses these comments, they must be
   * handled externally (pre-/post- processor wrappers).
   * @throws ConversionException - most likely caused by an ontology term that does not a correspond
   * to any database entry in the IDF or an unidentified node type.
   */
  public void populate() throws ConversionException {
    setType();
    setName(node.getNodeName());
    if(AppUtils.checkForAddition(node.getNodeName())) {
      addition = true;
    }
    this.dbId = AppUtils.filterIdToken(node.getNodeName());
    if(node.getNodeType().endsWith("file")) {
      setUri(node.getNodeName());
    }
    populateCharacteristics(node);
    String[] headers = node.headers();
	String[] values = node.values();
	for(int i = headers.length - 1; i >= 0; i--) {
	  //System.out.println("Node Name: " + name + " " + i + ":\t" + headers[i] + " = " + values[i]);
	  if(headers[i].startsWith("Description")) {
		setDescription(values[i]);
	  }
	  if("ProtAppNode Name".equals(SDRFUtils.parseHeader(COMMENT, headers[i]))) {
	    setName(values[i]);
	    // Needed because node name in limpopo is really file uri but any
	    // addition id will be on this comment.
	    this.dbId = AppUtils.filterIdToken(values[i]);
	  }
	  if("Data Table".equals(SDRFUtils.parseHeader(COMMENT, headers[i]))) {
	    setTable(values[i]);
	  }
	  if("ExtDbRls".equals(SDRFUtils.parseHeader(COMMENT, headers[i]))) {
	    setExtDbRls(values[i]);
	  }
	  if("Source Id".equals(SDRFUtils.parseHeader(COMMENT, headers[i]))) {
        setSourceId(values[i]);
      }
	  if("Uri".equals(SDRFUtils.parseHeader(COMMENT, headers[i]))) {
	    setUri(values[i]);
	  }
	}   
  }
  
  /**
   * Identifies this node as either a data item or a material entity.
   * Policy 5 - Set the type tag in the protocol_app_node element as follows: 'material entity'
   * for Source Name, Sample Name, Extract Name, Labeled Extract Name'; 'data item' for Scan Name,
   * and any Data File node. Regarding Assay Name, set it to 'data item' if it's followed by
   * a Comment [Uri], else set it to 'material entity'. 
   * @throws ConversionException - caused by an unidentified node type.
   */
  protected void setType() throws ConversionException {
	String nodeType = node.getNodeType();
	try {
	  if(nodeType.endsWith("file")
        || nodeType.contains(SCAN_NAME)
        || (
            nodeType.contains(ASSAY_NAME)
              && node.headers().length > 1
              && URI.equalsIgnoreCase(SDRFUtils.parseHeader(COMMENT, node.headers()[1])))
           ) {
        type = DATA_ITEM;
      }
	  else if(Arrays.asList(POSSIBLE_MATERIAL_ENTITIES).contains(nodeType)) {
        type = MATERIAL_ENTITY;
      }
	  else {
	    throw new Exception("1103:The type of the offending node - " + nodeType);
	  }
	}
	catch(Exception e) {
	  ErrorItemFactory factory = ErrorItemFactory.getErrorItemFactory();
      String msg = e.getMessage().split(":").length > 1 ? e.getMessage().split(":")[1] : e.getMessage();
      ErrorItem error = factory.generateErrorItem(msg, Integer.valueOf(e.getMessage().split(":")[0]), this.getClass());
      throw new ConversionException(true, e, error);
	}
  }
  
  public static ProtocolApplicationIONode findByNode(Node node) {
    ProtocolApplicationIONode found = null;
	for(ProtocolApplicationIONode applicationIONode : ProtocolApplicationIONode.applicationIONodes) {
	  if(node.equals(applicationIONode.getNode())) {
	    found = applicationIONode;
	  }
	}
	return found;
  }
  
  /**
   * Helper method to populate a list of characteristics as defined by the Characteristics
   * class.  Elements of a characteristics class are found in only 4 SDRF nodes and are 
   * based upon what MAGE-TAB refers to as characteristics and material types.  Note that
   * taxon is a MAGE-TAB characteristic, but it is pulled out as the property of this class.
   * @param populationNode - SDRF node from which to cull characteristics
   * @throws ConversionException - occurs when the creation of an ontology term fails.
   */
  protected void populateCharacteristics(SDRFNode populationNode) throws ConversionException {
    characteristics = new ArrayList<>();
    List<CharacteristicsAttribute> attributes = new ArrayList<>();
    MaterialTypeAttribute material = null;
    SDRFNodeNames nodeNames = SDRFNodeNames.valueOf(populationNode.getNodeType().toUpperCase());
    switch(nodeNames) {
      case SOURCENAME:
        attributes = ((SourceNode) populationNode).characteristics;
        material = ((SourceNode)populationNode).materialType;
        break;
      case SAMPLENAME:
        attributes = ((SampleNode) populationNode).characteristics;
        material = ((SampleNode)populationNode).materialType;
        break;
      case EXTRACTNAME:
        attributes = ((ExtractNode) populationNode).characteristics;
        material = ((ExtractNode)populationNode).materialType;
        break;
      case LABELEXTRACTNAME:
        attributes = ((LabeledExtractNode) populationNode).characteristics;
        material = ((LabeledExtractNode)populationNode).materialType;
        break;
      default:
        break;
    }
    for(CharacteristicsAttribute attribute : attributes) {
      if(ORGANISM.equalsIgnoreCase(SDRFUtils.parseHeader(attribute.getAttributeType()))) {
        setTaxon(attribute.getAttributeValue());
      }
      else {
        characteristics.add(new Characteristic(attribute));
      }
    }
    if(material != null) {
      characteristics.add(new Characteristic(material));
    }
  }
  
}
