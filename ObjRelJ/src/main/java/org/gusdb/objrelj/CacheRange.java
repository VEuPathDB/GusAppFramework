package org.gusdb.objrelj;

/**
 * CacheRange.java
 *
 * A pair of Longs that represents a range or interval to be cached.
 * Could be given a better name and/or made more generic.
 *
 * Created: Mon Mar 31 10:05:16 EST 2003
 *
 * @author Jonathan Crabtree
 * @version $Revision$ $Date$ $Author$
 */
public class CacheRange implements java.io.Serializable {

    // ------------------------------------------------------------------
    // Instance variables
    // ------------------------------------------------------------------

    private static final long serialVersionUID = 1L;

    /**
     * Start coordinate of the interval to cache.
     */
    public Long start = null;

    /**
     * End coordinate of the interval to cache.
     */
    public Long end = null;

    /**
     * Full length of the underlying object.
     */
    public Long length = null;

    // ------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------

    public CacheRange (Long start, Long end, Long length) 
    {
	this.start = start;
	this.end = end;
	this.length = length;
    }

    public CacheRange (long start, long end, long length) 
    {
	this.start = Long.valueOf(start);
	this.end = Long.valueOf(end);
	this.length = Long.valueOf(length);
    }

    // ------------------------------------------------------------------
    // Public methods
    // ------------------------------------------------------------------

    // Accessors
    public Long getStart() { return this.start; }
    public Long getEnd() { return this.end; }

    @Override
    public String toString() {
	return "[CacheRange:start=" + start + ",end=" + end + ",length=" + length + "]";
    }

}
