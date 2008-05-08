#ifndef NGUI_PROPERTY_COLLECTION_CONTROL_H
#define NGUI_PROPERTY_COLLECTION_CONTROL_H

// K-3D
// Copyright (c) 1995-2008, Timothy M. Shead
//
// Contact: tshead@k-3d.com
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public
// License as published by the Free Software Foundation; either
// version 2 of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// General Public License for more details.
//
// You should have received a copy of the GNU General Public
// License along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

/** \file
	\author Tim Shead (tshead@k-3d.com)
*/

#include <k3dsdk/iproperty_group_collection.h>
#include <k3dsdk/types.h>
#include <vector>

namespace Gtk { class Widget; }
namespace libk3dngui { class document_state; }

namespace k3d
{

class icommand_node;
class iproperty;
class iunknown;

namespace ngui
{

namespace property_collection
{

/// Provides a widget that auto-generates controls for a collection of properties
class control
{
public:
	control(libk3dngui::document_state& DocumentState, icommand_node& Parent);
	~control();

	/// Auto-generate controls for a single object of arbitrary type.
	void set_properties(iunknown* Object);
	/// Auto-generate controls for a collection of objects of arbitrary type.
	template<typename iterator_t>
	void set_properties(const iterator_t& Begin, const iterator_t& End)
	{
		set_properties(objects_t(Begin, End));
	}
	/// Auto-generate controls for a collection of properties organized into arbitrary groups.
	void set_properties(const iproperty_group_collection::groups_t& PropertyGroups);

	/// Called to get the toolbar widget for display
	Gtk::Widget& get_widget();

private:
	typedef std::vector<iunknown*> objects_t;
	void set_properties(const objects_t& Objects);

	class implementation;
	implementation* const m_implementation;
};

} // namespace property_collection

} // namespace ngui

} // namespace k3d

#endif // NGUI_PROPERTY_COLLECTION_CONTROL_H
