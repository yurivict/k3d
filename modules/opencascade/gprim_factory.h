// K-3D
// Copyright (c) 1995-2007, Timothy M. Shead
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

#include <k3dsdk/mesh.h>
#include <k3dsdk/point4.h>

namespace module
{

namespace opencascade
{

/// Provides a simplified interface for adding geometric primitives to a mesh
/** \todo Move this into the sdk once it matures for awhile */
class gprim_factory
{
public:
	/// Construct with a reference to the mesh to which the primitives will be added.
	gprim_factory(k3d::mesh& Mesh);
	~gprim_factory();

	/// Adds a new point to the Mesh.points array
	void add_point(const k3d::point3& Point);
	void add_point(const k3d::point4& Point);
	
	/// Creates a polygon, given the corner indices
	void add_polygon(const k3d::mesh::indices_t& Points);
	
	/// Adds a new NURBS patch. Returns true if successful
	/**
	 * \param UOrder Order in the U direction
	 * \param VOrder Order in the V direction
	 * \param Points Control points as indices into the Mesh.points array of this mesh, as added by add_point
	 * \param UKnots U knot vector
	 * \param VKnots V knot vector
	 * \param Weights Weigts associated with each control point
	 */
	bool add_nurbs_patch(const size_t UOrder, const size_t VOrder, const k3d::mesh::indices_t& Points, const k3d::mesh::knots_t& UKnots, const k3d::mesh::knots_t VKnots, const k3d::mesh::weights_t& Weights);
	/// Adds a new trim curve to the last loop of the last patch. Returns true if succesful.
	/**
	 *  Note: Trim curves need to be added in the order they will appear in the trim curve loop
	 *  \param Order The order of the NURBS curve
	 *  \param Points The control points of the curve, added as a vector of k3d::point2. When the next curve is added or the loop is closed,
	 *  the last k3d::point2 added is removed and linked to the next one
	 *  \param Knots the knot vector, repeating knots that have multiplicity > 1
	 *  \param Weights the weights associated with the control points 
	 */
	bool add_trim_curve(const k3d::uint_t Order, const k3d::mesh::points_2d_t& Points, const k3d::mesh::knots_t& Knots, const k3d::mesh::weights_t& Weights);
	/// Closes the last trim curve loop, removing the last k3d::point2 added and linking back to the start of the loop.
	void close_trim_loop();
	/// Adds a new NURBS curve to the mesh. Parameters similar to add_nurbs_patch.
	void add_nurbs_curve(const k3d::uint_t Order, const k3d::mesh::indices_t& Points, const k3d::mesh::knots_t& Knots, const k3d::mesh::weights_t& Weights);

private:
	class implementation;
	implementation* const m_implementation;
};

} // opencascade

} // module
