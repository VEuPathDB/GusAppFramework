package org.gusdb.gus.wdk.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;


/**
 * @author art
 *
 * TODO To change the template for this generated type comment go to
 * Window - Preferences - Java - Code Generation - Code and Comments
 */
public class FixableSmallMap implements Map {

    private Set keys = new FixableSmallSet();
    
    private Set entries = new FixableSmallSet();
    
    private List values = new ArrayList();
    
    /* (non-Javadoc)
     * @see java.util.Map#size()
     */
    public int size() {
        return keys.size();
    }

    /* (non-Javadoc)
     * @see java.util.Map#isEmpty()
     */
    public boolean isEmpty() {
        return keys.isEmpty();
    }

    /* (non-Javadoc)
     * @see java.util.Map#containsKey(java.lang.Object)
     */
    public boolean containsKey(Object key) {
        return keys.contains(key);
    }

    /* (non-Javadoc)
     * @see java.util.Map#containsValue(java.lang.Object)
     */
    public boolean containsValue(Object value) {
        return values.contains(value);
    }

    /* (non-Javadoc)
     * @see java.util.Map#get(java.lang.Object)
     */
    public Object get(Object key) {
        if (keys.contains(key)) {
            Iterator it = entrySet().iterator();
            while (it.hasNext()) {
                Map.Entry em = (Map.Entry) it.next();
                if (key.equals(em.getKey())) {
                    return em.getValue();
                }
            }
        }
        return null;
    }

    /* (non-Javadoc)
     * @see java.util.Map#put(java.lang.Object, java.lang.Object)
     */
    public Object put(Object key, Object value) {
        if (keys.contains(key)) {
            return null;
        }
        Map.Entry entry = new SmallMapEntry(key, value);
        entries.add(entry);
        keys.add(key);
        values.add(value);
        return entry;
    }

    /* (non-Javadoc)
     * @see java.util.Map#remove(java.lang.Object)
     */
    public Object remove(Object key) {
        return new UnsupportedOperationException("remove not permitted on FixableSmallMap");
    }

    /* (non-Javadoc)
     * @see java.util.Map#putAll(java.util.Map)
     */
    public void putAll(Map t) {
        // TODO Auto-generated method stub

    }

    /* (non-Javadoc)
     * @see java.util.Map#clear()
     */
    public void clear() {
        // TODO Auto-generated method stub

    }

    /* (non-Javadoc)
     * @see java.util.Map#keySet()
     */
    public Set keySet() {
        return keys;
    }

    /* (non-Javadoc)
     * @see java.util.Map#values()
     */
    public Collection values() {
        return values;
    }

    /* (non-Javadoc)
     * @see java.util.Map#entrySet()
     */
    public Set entrySet() {
        return entries;
    }


    
    private class SmallMapEntry implements Map.Entry {

        private Object key;
        private Object value;
        
        
        
        
        /**
         * @param key
         * @param value
         */
        public SmallMapEntry(Object key, Object value) {
            this.key = key;
            this.value = value;
        }
        
        /* (non-Javadoc)
         * @see java.util.Map.Entry#getKey()
         */
        public Object getKey() {
            return key;
        }

        /* (non-Javadoc)
         * @see java.util.Map.Entry#getValue()
         */
        public Object getValue() {
            return value;
        }

        /* (non-Javadoc)
         * @see java.util.Map.Entry#setValue(java.lang.Object)
         */
        public Object setValue(Object value) {
            this.value = value;
            return value;
        }
        
    }
    
}
