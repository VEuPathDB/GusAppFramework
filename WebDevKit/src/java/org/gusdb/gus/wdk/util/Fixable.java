package org.gusdb.gus.wdk.util;

public interface Fixable {

    public void fix();
    
    public boolean isFixed();
    
    public boolean usableBeforeFixing(); 
    
}
