/*
 * Copyright (c) 2014 Oracle and/or its affiliates. All rights reserved. This
 * code is released under a tri EPL/GPL/LGPL license. You can use it,
 * redistribute it and/or modify it under the terms of the:
 *
 * Eclipse Public License version 1.0
 * GNU General Public License version 2
 * GNU Lesser General Public License version 2.1
 */
package org.jruby.truffle.runtime.backtrace;

import com.oracle.truffle.api.nodes.Node;

import java.util.Arrays;
import java.util.Collections;
import java.util.List;

public class Backtrace {

    private final Activation[] activations;

    public Backtrace(Activation[] activations) {
        this.activations = activations;
    }

    public List<Activation> getActivations() {
        return Collections.unmodifiableList(Arrays.asList(activations));
    }

}
