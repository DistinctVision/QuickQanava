/*
 Copyright (c) 2008-2022, Benoit AUTHEMAN All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the author or Destrat.io nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL AUTHOR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

import QtQuick 2.7

import QuickQanava 2.0 as Qan

/*! \brief Concrete component for qan::NavigablePreview interface.
 *
 */
Qan.AbstractNavigablePreview {
    id: preview
    clip: true

    // PUBLIC /////////////////////////////////////////////////////////////////

    //! Overlay item could be used to display a user defined item (for example an heat map image) between the background and the current visible window rectangle.
    property var    overlay: overlayItem

    //! Color for the visible window rect border (default to red).
    property color  viewWindowColor: Qt.rgba(1, 0, 0, 1)

    //! Show or hide the target navigable content as a background image (default to true).
    property alias  backgroundPreviewVisible: sourcePreview.visible

    //! Initial (and minimum) scene rect (should usually fit your initial screen size).
    property rect   initialRect: Qt.rect(-1280 / 2., -720 / 2.,
                                         1280, 720)

    // PRIVATE ////////////////////////////////////////////////////////////////
    onSourceChanged: {
        if (source &&
            source.containerItem) {
            resetVisibleWindow()

            // Monitor source changes
            source.containerItem.onWidthChanged.connect(updatePreview)
            source.containerItem.onHeightChanged.connect(updatePreview)
            source.containerItem.onScaleChanged.connect(updatePreview)
            source.containerItem.onXChanged.connect(updatePreview)
            source.containerItem.onYChanged.connect(updatePreview)
            source.containerItem.onChildrenRectChanged.connect(updatePreview)

            sourcePreview.sourceItem = source.containerItem
        } else
            sourcePreview.sourceItem = undefined
        updatePreview()
        updateVisibleWindow()
    }

    ShaderEffectSource {
        id: sourcePreview
        anchors.fill: parent
        anchors.margins: 0
        live: true
        recursive: false
        textureSize: Qt.size(width, height)
    }

    function updatePreview() {
        if (!source)
            return
        const r = computeSourceRect()
        if (r &&
            r.width > 0. &&
            r.height > 0) {
            sourcePreview.sourceRect = r
            viewWindow.visible = true
            updateVisibleWindow(r)
        } else
            viewWindow.visible = false
    }

    function computeSourceRect(rect) {
        if (!source)
            return undefined
        if (!preview.source ||
            !preview.source.containerItem ||
            sourcePreview.sourceItem !== preview.source.containerItem)
            return undefined

        // Scene rect is union of initial rect and children rect.
        let cr = preview.source.containerItem.childrenRect
        let r = preview.rectUnion(cr, preview.initialRect)
        return r
    }

    // Reset viewWindow rect to preview dimension (taking rectangle border into account)
    function    resetVisibleWindow() {
        const border = viewWindow.border.width
        const border2 = border * 2
        viewWindow.x = border
        viewWindow.y = border
        viewWindow.width = preview.width - border2
        viewWindow.height = preview.height - border2
    }

    function    updateVisibleWindow(r) {
        // r is previewed rect in source.containerItem Cs
        if (!preview)
            return
        if (!source) {  // Reset the window when source is invalid
            preview.resetVisibleWindow()
            return
        }
        var containerItem = source.containerItem
        if (!containerItem) {
            preview.resetVisibleWindow()
            return
        }
        if (!r)
            return

        //if (r.width < preview.source.width && // If scene size is stricly inferior to preview size
        //    r.height < preview.source.height) {         // reset the preview window
        //    r.width = preview.source.width
        //    r.height = preview.source.height
        //}
        //if (r.width < 0.01 ||        // Do not update without a valid children rect
        //    r.height < 0.01) {
        //    preview.resetVisibleWindow()
        //    return
        //}
        //if (r.width < r.width ||        // Reset the visible window is the whole containerItem content
        //    r.height < r.height) {       // is smaller than graph view
        //    preview.resetVisibleWindow()
        //    return
        //}
        //if (r.width < preview.width && // If scene size is stricly inferior to preview size
        //    r.height < preview.height) {         // reset the preview window
        //    preview.resetVisibleWindow()
        //    return
        //}

        // r is content rect
        // viewR is window rect in content rect Cs
        // Window is viewR in preview Cs

        const border = viewWindow.border.width
        const border2 = border * 2.

        // map r to preview
        // map viewR to preview
        // Apply scaling from r to preview
        const viewR = preview.source.mapToItem(preview.source.containerItem,
                                               Qt.rect(0, 0,
                                                       preview.source.width,
                                                       preview.source.height))
        var previewXRatio = preview.width / r.width
        var previewYRatio = preview.height / r.height

        viewWindow.visible = true
        viewWindow.x = (previewXRatio * (viewR.x - r.x)) + border
        viewWindow.y = (previewYRatio * (viewR.y - r.y)) + border
        viewWindow.width = (previewXRatio * viewR.width) - border2
        viewWindow.height = (previewYRatio * viewR.height) - border2

        visibleWindowChanged(Qt.rect(viewWindow.x / preview.width,
                                  viewWindow.y / preview.height,
                                  viewWindow.width / preview.width,
                                  viewWindow.height / preview.height),
                             source.zoom);
    }
    Item {
        id: overlayItem
        anchors.fill: parent; anchors.margins: 0
    }
    Rectangle {
        id: viewWindow
        color: Qt.rgba(0, 0, 0, 0)
        smooth: true
        antialiasing: true
        border.color: viewWindowColor
        border.width: 2
    }
    // Not active on 20201027
    /*MouseArea {
        id: viewWindowDragger
        anchors.fill: parent
        drag.onActiveChanged: {
            console.debug("dragging to:" + viewWindow.x + ":" + viewWindow.y );
            if ( source ) {
            }
        }
        drag.target: viewWindow
        drag.threshold: 1.      // Note 20170311: Avoid a nasty delay between mouse position and dragged item position
        // Do not allow dragging outside preview area
        drag.minimumX: 0; drag.maximumX: Math.max(0, preview.width - viewWindow.width)
        drag.minimumY: 0; drag.maximumY: Math.max(0, preview.height - viewWindow.height)
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        hoverEnabled: true
        enabled: true
        onReleased: {
        }
        onPressed : {
        }
    }*/
}  // Qan.AbstractNavigablePreview: preview
